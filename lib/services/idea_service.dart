import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart' show CompressFormat;
import 'package:invist_bh/models/idea_model.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

class IdeaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
  final CollectionReference _ideasCollection = 
      FirebaseFirestore.instance.collection('ideas');

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String fileName) async {
    try {
      // Get file extension and ensure it's lowercase
      final String extension = p.extension(imageFile.path).toLowerCase();
      
      // Create temporary directory to store compressed image
      final Directory tempDir = await path_provider.getTemporaryDirectory();
      final String targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}$extension';
      
      // Compress the image
      File? compressedFile = await compressImage(imageFile, targetPath);
      
      // Use compressed file if available, otherwise use original
      final File fileToUpload = compressedFile ?? imageFile;
      
      // Generate a short, unique filename (9 chars or less)
      // Use a combination of random characters to ensure uniqueness
      final String randomChars = DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13);
      
      // Create a short filename with just the random characters (5 chars) + extension
      String finalFileName = 'img$randomChars';
      
      // Ensure the filename has the correct extension
      if (!finalFileName.toLowerCase().endsWith(extension)) {
        finalFileName = finalFileName + extension;
      }
      
      // Check if file size is still too large - set a strict 2MB limit for Firebase Storage
      final int fileSize = await fileToUpload.length();
      if (fileSize > 2 * 1024 * 1024) {
        throw Exception('Image is too large (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB). Please use a smaller image (max 2MB).');
      }
      
      // Upload to Firebase Storage with metadata
      final Reference storageRef = _storage.ref().child('idea_images/$finalFileName');
      
      // Add content type metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/${extension.replaceFirst('.', '')}',
        customMetadata: {'originalFileName': p.basename(imageFile.path)},
      );
      
      // Use chunked upload for better reliability
      final UploadTask uploadTask = storageRef.putFile(fileToUpload, metadata);
      
      // Monitor upload progress with more detailed logging
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(2);
        print('Upload progress: $progress% | File: $finalFileName | Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      }, onError: (e) {
        print('Upload error details: $e');
        print('Failed file: $finalFileName | Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      });
      
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      // Clean up temporary file if it was created
      if (compressedFile != null && compressedFile.existsSync()) {
        await compressedFile.delete();
      }
      
      return downloadUrl;
    } catch (e) {
      print('Upload error details: $e');
      print('Error stack trace: ${StackTrace.current}');
      // Provide a more user-friendly error message
      if (e.toString().contains('firebase_storage/unknown')) {
        throw Exception('Failed to upload image: The file may be too large or in an unsupported format. Please try a different image.');
      } else {
        throw Exception('Failed to upload image: $e');
      }
    }
  }
  
  // Helper method to compress image
  Future<File?> compressImage(File file, String targetPath) async {
    try {
      // Get original file size in bytes
      final int originalSize = await file.length();
      print('Original image size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // If file is already small enough, return it directly
      if (originalSize < 500 * 1024) { // Less than 500KB
        print('Image already small enough, skipping compression');
        return file;
      }
      
      // Get file extension and ensure it's lowercase
      final String extension = p.extension(file.path).toLowerCase();
      
      // Always convert to JPEG for better compression (except for PNGs with transparency)
      final bool keepAsPng = extension == '.png';
      final CompressFormat format = keepAsPng ? CompressFormat.png : CompressFormat.jpeg;
      
      // Prepare target path with appropriate extension
      final String finalExtension = keepAsPng ? '.png' : '.jpg';
      final String finalTargetPath = targetPath.replaceAll(RegExp(r'\.[^.]*$'), '') + finalExtension;
      
      // Set aggressive compression for all images
      int quality = 50; // Start with medium quality
      int maxWidth = 800;
      int maxHeight = 800;
      
      // For larger files, use more aggressive settings
      if (originalSize > 2 * 1024 * 1024) { // > 2MB
        quality = 30;
        maxWidth = 600;
        maxHeight = 600;
      }
      
      // For PNG files, use higher quality but smaller dimensions
      if (keepAsPng) {
        quality = 70;
        maxWidth = 600;
        maxHeight = 600;
      }
      
      // First compression attempt
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        finalTargetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: format,
      );
      
      if (result == null) {
        print('Compression failed, using original file');
        return file;
      }
      
      File compressedFile = File(result.path);
      int compressedSize = await compressedFile.length();
      print('Compressed image size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // If compression made the file larger, use the original
      if (compressedSize > originalSize) {
        print('Compression increased file size, using original');
        if (compressedFile.existsSync()) {
          await compressedFile.delete();
        }
        return file;
      }
      
      // If still too large and not PNG, try more aggressive compression
      if (compressedSize > 1 * 1024 * 1024 && !keepAsPng) {
        final String secondAttemptPath = '${finalTargetPath}_2nd.jpg';
        final secondResult = await FlutterImageCompress.compressAndGetFile(
          compressedFile.absolute.path,
          secondAttemptPath,
          quality: 20,
          minWidth: 500,
          minHeight: 500,
          format: CompressFormat.jpeg,
        );
        
        // Delete the first compressed file
        if (compressedFile.existsSync()) {
          await compressedFile.delete();
        }
        
        if (secondResult != null) {
          File secondCompressedFile = File(secondResult.path);
          int secondCompressedSize = await secondCompressedFile.length();
          print('Second compression image size: ${(secondCompressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
          
          // If second compression made it larger, use original
          if (secondCompressedSize > originalSize) {
            if (secondCompressedFile.existsSync()) {
              await secondCompressedFile.delete();
            }
            return file;
          }
          
          return secondCompressedFile;
        }
      }
      
      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original file if compression fails
    }
  }

  // Add a new idea
  Future<String> addIdea(IdeaModel idea) async {
    try {
      final DocumentReference docRef = await _ideasCollection.add(idea.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add idea: $e');
    }
  }

  // Get all ideas
  Stream<List<IdeaModel>> getIdeas() {
    return _ideasCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IdeaModel.fromFirestore(doc))
            .toList());
  }

  // Get ideas by category
  Stream<List<IdeaModel>> getIdeasByCategory(String category) {
    return _ideasCollection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IdeaModel.fromFirestore(doc))
            .toList());
  }

  // Get ideas by creator
  Stream<List<IdeaModel>> getIdeasByCreator(String creatorId) {
    return _ideasCollection
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IdeaModel.fromFirestore(doc))
            .toList());
  }

  // Add investor to idea
  Future<void> addInvestorToIdea(String ideaId, String investorId) async {
    try {
      await _ideasCollection.doc(ideaId).update({
        'investors': FieldValue.arrayUnion([investorId])
      });
    } catch (e) {
      throw Exception('Failed to add investor: $e');
    }
  }
  
  // Update an existing idea
  Future<void> updateIdea(IdeaModel idea) async {
    try {
      await _ideasCollection.doc(idea.id).update(idea.toMap());
    } catch (e) {
      throw Exception('Failed to update idea: $e');
    }
  }
  
  // Request access to idea details
  Future<void> requestIdeaAccess(String ideaId, String investorId) async {
    try {
      // Create a subcollection for access requests
      await _ideasCollection.doc(ideaId).collection('accessRequests').doc(investorId).set({
        'investorId': investorId,
        'status': 'pending',
        'requestedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to request access: $e');
    }
  }
  
  // Get all access requests for an idea
  Stream<QuerySnapshot> getIdeaAccessRequests(String ideaId) {
    return _ideasCollection
        .doc(ideaId)
        .collection('accessRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
  
  // Approve access request
  Future<void> approveAccessRequest(String ideaId, String investorId) async {
    try {
      // Update the request status
      await _ideasCollection
          .doc(ideaId)
          .collection('accessRequests')
          .doc(investorId)
          .update({'status': 'approved'});
      
      // Add investor to the idea's investors list
      await addInvestorToIdea(ideaId, investorId);
    } catch (e) {
      throw Exception('Failed to approve access: $e');
    }
  }
  
  // Reject access request
  Future<void> rejectAccessRequest(String ideaId, String investorId) async {
    try {
      await _ideasCollection
          .doc(ideaId)
          .collection('accessRequests')
          .doc(investorId)
          .update({'status': 'rejected'});
    } catch (e) {
      throw Exception('Failed to reject access: $e');
    }
  }
  
  // Check if investor has access to idea details
  Future<bool> checkInvestorAccess(String ideaId, String investorId) async {
    try {
      final ideaDoc = await _ideasCollection.doc(ideaId).get();
      final idea = IdeaModel.fromFirestore(ideaDoc);
      return idea.investors.contains(investorId);
    } catch (e) {
      throw Exception('Failed to check access: $e');
    }
  }
  
  // Get all access requests made by an investor
  Stream<List<Map<String, dynamic>>> getInvestorAccessRequests(String investorId) {
    // Create a stream controller to combine results
    final controller = StreamController<List<Map<String, dynamic>>>();
    
    // Get all ideas
    _ideasCollection.snapshots().listen((ideasSnapshot) async {
      List<Map<String, dynamic>> requests = [];
      
      // For each idea, check if the investor has made a request
      for (var ideaDoc in ideasSnapshot.docs) {
        final idea = IdeaModel.fromFirestore(ideaDoc);
        
        // Get the access request document for this investor
        try {
          final requestDoc = await _ideasCollection
              .doc(idea.id)
              .collection('accessRequests')
              .doc(investorId)
              .get();
          
          if (requestDoc.exists) {
            final requestData = requestDoc.data() as Map<String, dynamic>;
            requests.add({
              'ideaId': idea.id,
              'ideaTitle': idea.title,
              'ideaCategory': idea.category,
              'ideaImageUrl': idea.imageUrl,
              'status': requestData['status'],
              'requestedAt': requestData['requestedAt'],
            });
          }
        } catch (e) {
          print('Error fetching request for idea ${idea.id}: $e');
        }
      }
      
      // Add the combined results to the stream
      controller.add(requests);
    }, onError: (e) {
      controller.addError(e);
    });
    
    return controller.stream;
  }
}
